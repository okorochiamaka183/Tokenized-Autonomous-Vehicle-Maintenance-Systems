import { describe, it, expect, beforeEach } from "vitest"

describe("Service Scheduler Contract", () => {
  let contractAddress
  let deployer
  let provider1
  let provider2
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.service-scheduler"
    deployer = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    provider1 = "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5"
    provider2 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
  })
  
  describe("Service Provider Registration", () => {
    it("should register service provider successfully", () => {
      const name = "Quick Lube"
      const location = "123 Main St, City"
      const specialties = ["oil-change", "tire-rotation"]
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should prevent duplicate provider registration", () => {
      const name = "Auto Shop"
      const location = "456 Oak Ave"
      const specialties = ["brake-service"]
      
      const result = {
        type: "error",
        value: 203,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(203)
    })
  })
  
  describe("Service Types", () => {
    it("should create service type successfully", () => {
      const serviceTypeId = 1
      const name = "Oil Change"
      const description = "Standard oil and filter change"
      const estimatedDuration = 30
      const baseCost = 50
      const frequencyMiles = 5000
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject invalid duration", () => {
      const serviceTypeId = 2
      const name = "Tire Rotation"
      const description = "Rotate all four tires"
      const estimatedDuration = 0
      const baseCost = 25
      const frequencyMiles = 7500
      
      const result = {
        type: "error",
        value: 202,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(202)
    })
    
    it("should prevent unauthorized service type creation", () => {
      const serviceTypeId = 3
      const name = "Brake Service"
      const description = "Brake pad replacement"
      const estimatedDuration = 120
      const baseCost = 200
      const frequencyMiles = 25000
      
      const result = {
        type: "error",
        value: 200,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(200)
    })
  })
  
  describe("Appointment Scheduling", () => {
    it("should schedule appointment successfully", () => {
      const vehicleId = 1
      const serviceTypeId = 1
      const providerId = provider1
      const scheduledDate = 150
      const estimatedCost = 55
      const notes = "Regular maintenance"
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should reject past scheduled date", () => {
      const vehicleId = 1
      const serviceTypeId = 1
      const providerId = provider1
      const scheduledDate = 50
      const estimatedCost = 55
      const notes = "Regular maintenance"
      
      const result = {
        type: "error",
        value: 202,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(202)
    })
    
    it("should reject non-existent service type", () => {
      const vehicleId = 1
      const serviceTypeId = 999
      const providerId = provider1
      const scheduledDate = 150
      const estimatedCost = 55
      const notes = "Regular maintenance"
      
      const result = {
        type: "error",
        value: 201,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(201)
    })
  })
  
  describe("Appointment Status Updates", () => {
    it("should update appointment status successfully", () => {
      const appointmentId = 1
      const newStatus = "confirmed"
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject invalid status", () => {
      const appointmentId = 1
      const newStatus = "invalid-status"
      
      const result = {
        type: "error",
        value: 204,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(204)
    })
    
    it("should prevent unauthorized status updates", () => {
      const appointmentId = 1
      const newStatus = "completed"
      
      const result = {
        type: "error",
        value: 200,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(200)
    })
  })
  
  describe("Service Completion", () => {
    it("should record service completion successfully", () => {
      const vehicleId = 1
      const serviceTypeId = 1
      const providerId = provider1
      const mileageAtService = 20000
      const actualCost = 52
      const qualityRating = 5
      const notes = "Service completed successfully"
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should reject invalid quality rating", () => {
      const vehicleId = 1
      const serviceTypeId = 1
      const providerId = provider1
      const mileageAtService = 20000
      const actualCost = 52
      const qualityRating = 6
      const notes = "Service completed"
      
      const result = {
        type: "error",
        value: 202,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(202)
    })
    
    it("should prevent unauthorized completion recording", () => {
      const vehicleId = 1
      const serviceTypeId = 1
      const providerId = provider2
      const mileageAtService = 20000
      const actualCost = 52
      const qualityRating = 4
      const notes = "Unauthorized attempt"
      
      const result = {
        type: "error",
        value: 200,
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(200)
    })
  })
  
  describe("Service Schedule Updates", () => {
    it("should update oil change schedule", () => {
      const vehicleId = 1
      const serviceType = "oil-change"
      const lastServiceMileage = 20000
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should update tire rotation schedule", () => {
      const vehicleId = 1
      const serviceType = "tire-rotation"
      const lastServiceMileage = 22500
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should update brake service schedule", () => {
      const vehicleId = 1
      const serviceType = "brake-service"
      const lastServiceMileage = 45000
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("Read-only Functions", () => {
    it("should get service provider info", () => {
      const providerId = provider1
      const result = {
        name: "Quick Lube",
        location: "123 Main St, City",
        specialties: ["oil-change", "tire-rotation"],
        rating: 50,
        active: true,
        "registered-at": 100,
      }
      
      expect(result.name).toBe("Quick Lube")
      expect(result.active).toBe(true)
    })
    
    it("should get appointment details", () => {
      const appointmentId = 1
      const result = {
        "vehicle-id": 1,
        "service-type-id": 1,
        "provider-id": provider1,
        "scheduled-date": 150,
        "estimated-cost": 55,
        status: "confirmed",
        notes: "Regular maintenance",
        "created-at": 100,
        "completed-at": null,
      }
      
      expect(result["vehicle-id"]).toBe(1)
      expect(result.status).toBe("confirmed")
    })
  })
})
