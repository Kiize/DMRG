using ITensors
using Statistics
using Plots

# Inizializzazione.

N = 100 # Numero siti.
sites = siteinds("Fermion", N) # N Fermions.

####################################### Costruiamo l'hamiltoniana XY.
"""
function H_xy(N)
    os = OpSum()
    for i in 1:N-1
        os += "Cdag", i, "C", i+1
        os += "C", i, "Cdag", i+1
    end 

    return os
end

Hxy = H_xy(N)
"""
####################################### Costruiamo l'hamiltoniana XX (vedi Sachdev 16.1).
function H_xx(N, h)
    os = OpSum()
    for i in 1:N-1
        os -= "Cdag", i, "C", i+1
        os -= "C", i, "Cdag", i+1
        os -= h,"Cdag",i,"C",i  # h = μ/w
    end 

    os -= h,"Cdag",N,"C",N

    return os
end

####################################### DMRG. 

len = 100
occupation_numbers = zeros(len, N)
x = range(start = -3., stop = 3., length = len)

for (ind, h) in enumerate(x)
    Hxx = H_xx(N, h)
    H = MPO(Hxx,sites)  # Convertiamo H in un Matrix Product Operator.
        
    psi0 = random_mps(sites;linkdims=10)
    
    nsweeps = 6
    maxdim = [10,20,100,100,200,400]
    cutoff = [1E-10]
    
    energy,psi = dmrg(H,psi0;nsweeps,maxdim,cutoff)
    
    occupation_numbers[ind, :] = expect(psi, "N") # Calcoliamo <N> dove N è l'operatore densità.
end

y = mean(occupation_numbers, dims = 2)

####################################### Plot.
plot(x, y, lab = "DMRG")

function theoretic_value(h)
    if h <= -2
        return 0
    elseif h>= 2
        return 1
    else
        return 1 - 1 / pi * acos(h/2)
    end
end

plot!(x, theoretic_value.(x), lab = "theoretical value")
xlabel!("\$ μ/ \\textrm{w} \$")
ylabel!("\$ < \\textrm{n}_i> \$")

savefig("figures/xx.png")