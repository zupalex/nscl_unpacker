#include <iostream>
#include <vector>

#include "UserClassBase.h"

using namespace std;

// ----------------- SIDAR Class ------------------------- //

class SIDAR_detclass: public LuaUserClass {
// This class is for ASICs hit
public:
	SIDAR_detclass()
	{
	}

  int detID = -1;
  
	vector<short> dE_strips;
  vector<float> dE_energies;

	vector<short> E_strips;
  vector<float> E_energies;

	void Reset()
	{
		dE_strips.clear();
		dE_energies.clear();		
    E_strips.clear();
		E_energies.clear();
	}

	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &detID, "detID", "int");
		AddAccessor(L, &dE_strips, "dE_strips", "vector<short>");
		AddAccessor(L, &dE_energies, "dE_energies", "vector<float>");
    AddAccessor(L, &dE_strips, "E_strips", "vector<short>");
		AddAccessor(L, &dE_energies, "E_energies", "vector<float>");
	}
};

// ----------------- Barrel Class ------------------------- //

class Barrel_detclass: public LuaUserClass {
// This class is for ASICs hit
public:
	Barrel_detclass()
	{
	}

  int detID = -1;
  
	vector<short> dE_strips;
  vector<float> dE_energies;

	vector<short> E_strips;
  vector<float> E_energies;
  
  vector<short> E_contacts;
  vector<float> E_con_energies;

	void Reset()
	{
		dE_strips.clear();
		dE_energies.clear();		
    E_strips.clear();
		E_energies.clear();
    E_contacts.clear();
		E_con_energies.clear();
	}

	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &detID, "detID", "int");
		AddAccessor(L, &dE_strips, "dE_strips", "vector<short>");
		AddAccessor(L, &dE_energies, "dE_energies", "vector<float>");
    AddAccessor(L, &dE_strips, "E_strips", "vector<short>");
		AddAccessor(L, &dE_energies, "E_energies", "vector<float>");
    AddAccessor(L, &dE_strips, "E_contacts", "vector<short>");
		AddAccessor(L, &dE_energies, "E_con_energies", "vector<float>");
	}
};

// ----------------- Ion Chamber Class ------------------------- //

class IonChamber_detclass: public LuaUserClass {
// This class is for ASICs hit
public:
	IonChamber_detclass()
	{
	}
  
	vector<short> pads;
  vector<float> energies;
  
  float average_energy;

	void Reset()
	{
    average_energy = 0;
		pads.clear();
		energies.clear();		
	}

	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &pads, "pads", "vector<short>");
		AddAccessor(L, &energies, "energies", "vector<float>");
		AddAccessor(L, &average_energy, "average_energy", "float");
	}
};

// ----------------- CRDC Class ------------------------- //

class CRDC_detclass: public LuaUserClass {
// This class is for ASICs hit
public:
	CRDC_detclass()
	{
	}
  
  vector<short> pads;
	vector<vector<short>> sample_nbr;
  vector<vector<float>> raw;
  
  float time;
  float average_raw;
	float xgrav;

	void Reset()
	{
    pads.clear();
		sample_nbr.clear();
		raw.clear();		
    time = 0;
		xgrav = 0;
    average_raw = 0;
	}

	void MakeAccessors(lua_State* L)
	{
    AddAccessor(L, &pads, "pads", "vector<short>");
		AddAccessor(L, &sample_nbr, "sample_nbr", "vector<vector<short>>");
		AddAccessor(L, &raw, "raw", "vector<vector<float>>");
		AddAccessor(L, &time, "time", "float");
    AddAccessor(L, &average_raw, "average_raw", "float");
		AddAccessor(L, &xgrav, "xgrav", "float");
	}
};

// ----------------- MTDC Class ------------------------- //

class MTDC_detclass: public LuaUserClass {
// This class is for ASICs hit
public:
	MTDC_detclass()
	{
	}
  
	vector<unsigned int> xfp_hits;

  long long tof_xfp;

	void Reset()
	{
		xfp_hits.clear();
    tof_xfp = -99999;
	}

	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &xfp_hits, "xfp_hits", "vector<unsigned int>");
		AddAccessor(L, &tof_xfp, "tof_xfp", "long long");
	}
};

//// ----------------- TriggerPack Class ------------------------- //

//class TriggerPack: public LuaUserClass {
////This class is for S800 Trigger
//public:
//	TriggerPack()
//	{
//	}

//	int nhits = 0;
//	vector<int> registr, s800, external1, external2, secondary;

//	void Reset()
//	{
//		nhits = 0;

//		registr.clear();
//		s800.clear();
//		external1.clear();
//		external2.clear();
//		secondary.clear();
//	}


//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");
//		AddAccessor(L, &registr, "registr", "vector<int>");
//		AddAccessor(L, &s800, "s800", "vector<int>");
//		AddAccessor(L, &external1, "external1", "vector<int>");
//		AddAccessor(L, &external2, "external2", "vector<int>");
//		AddAccessor(L, &secondary, "secondary", "vector<int>");
//	}
//};

//// ----------------- TOFPack Class ------------------------- //

//class TOFPack: public LuaUserClass {
////This class is for S800 time of flight
//public:
//	TOFPack()
//	{
//	}

//	int nhits = 0;
//	vector<int> rf, obj, xfp, tar, tac_obj, tac_xfp;

//	void Reset()
//	{
//		nhits = 0;

//		rf.clear();
//		obj.clear();
//		xfp.clear();
//		tar.clear();
//		tac_obj.clear();
//		tac_xfp.clear();
//	}


//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");
//		AddAccessor(L, &rf, "rf", "vector<int>");
//		AddAccessor(L, &obj, "obj", "vector<int>");
//		AddAccessor(L, &xfp, "xfp", "vector<int>");
//		AddAccessor(L, &tar, "tar", "vector<int>");
//		AddAccessor(L, &tac_obj, "tac_obj", "vector<int>");
//		AddAccessor(L, &tac_xfp, "tac_xfp", "vector<int>");
//	}
//};

//// ----------------- ScintPack Class ------------------------- //

//class ScintPack: public LuaUserClass {
////This class is for S800 Scintillator
//public:
//	ScintPack()
//	{
//	}

//	int nhits = 0;
//	vector<int> de_up, de_down, time_up, time_down;

//	void Reset()
//	{
//		nhits = 0;

//		de_up.clear();
//		de_down.clear();
//		time_up.clear();
//		time_down.clear();
//	}


//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");
//		AddAccessor(L, &de_up, "de_up", "vector<int>");
//		AddAccessor(L, &de_down, "de_down", "vector<int>");
//		AddAccessor(L, &time_up, "time_up", "vector<int>");
//		AddAccessor(L, &time_down, "time_down", "vector<int>");
//	}
//};

//// ----------------- CRDCPack Class ------------------------- //

//class CRDCPack: public LuaUserClass {
////This class is for S800 Cathode readout drift chamber
//public:
//	CRDCPack()
//	{
//	}

//	int nhits = 0, rawCount = 0;
//	vector<int> id, anode, tac, width;
//	vector<vector<int>> data, sample, ch;

//	void Reset()
//	{
//		nhits = 0;
//		rawCount = 0;

//		id.clear();
//		anode.clear();
//		tac.clear();
//		width.clear();

//		data.clear();
//		sample.clear();
//		ch.clear();
//	}

//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");
//		AddAccessor(L, &rawCount, "rawCount", "vector<int>");
//		AddAccessor(L, &id, "id", "vector<int>");
//		AddAccessor(L, &anode, "anode", "vector<int>");
//		AddAccessor(L, &tac, "tac", "vector<int>");
//		AddAccessor(L, &width, "width", "vector<int>");

//		AddAccessor(L, &data, "data", "vector<vector<int>>");
//		AddAccessor(L, &sample, "sample", "vector<vector<int>>");
//		AddAccessor(L, &ch, "ch", "vector<vector<int>>");
//	}
//};

//// ----------------- ICPack Class ------------------------- //

//class ICPack: public LuaUserClass {
////This class is for S800 Ion Chamber
//public:
//	ICPack()
//	{
//		for (int i = 0; i < 16; i++)
//			data.push_back(vector<int>());
//	}

//	int nhits = 0;
//	vector<vector<int>> data;

//	void Reset()
//	{
//		nhits = 0;

//		for (int i = 0; i < 16; i++)
//			data[i].clear();
//	}


//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");

//		AddAccessor(L, &data, "data", "vector<vector<int>>");
//	}
//};

//// ----------------- TPPACPack Class ------------------------- //

//class TPPACPack: public LuaUserClass {
////This class is for S800 Tracking Parallel Plate Avalanche Counter
//public:
//	TPPACPack()
//	{
//	}

//	int nhits = 0;
//	vector<int> id, data, sample, ch;

//	void Reset()
//	{
//		nhits = 0;

//		id.clear();
//		data.clear();
//		sample.clear();
//		ch.clear();
//	}


//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");
//		AddAccessor(L, &id, "id", "vector<int>");
//		AddAccessor(L, &data, "data", "vector<int>");
//		AddAccessor(L, &sample, "sample", "vector<int>");
//		AddAccessor(L, &ch, "ch", "vector<int>");
//	}
//};

//// ----------------- HodoPack Class ------------------------- //

//class HodoPack: public LuaUserClass {
////This class is for S800 hodoscope
//public:
//	HodoPack()
//	{
//	}

//	int nhits = 0;
//	vector<int> ch, data, regA, regB, tac;

//	void Reset()
//	{
//		nhits = 0;

//		ch.clear();
//		data.clear();
//		regA.clear();
//		regB.clear();
//		tac.clear();
//	}


//	void MakeAccessors(lua_State* L)
//	{
//		AddAccessor(L, &nhits, "nhits", "int");
//		AddAccessor(L, &ch, "ch", "vector<int>");
//		AddAccessor(L, &data, "data", "vector<int>");
//		AddAccessor(L, &regA, "regA", "vector<int>");
//		AddAccessor(L, &regB, "regB", "vector<int>");
//		AddAccessor(L, &tac, "tac", "vector<int>");
//	}
//};

extern "C" int openlib_se84_detclasses(lua_State* L)
{
	MakeAccessFunctions<SIDAR_detclass>(L, "SIDAR_detclass");
	MakeAccessFunctions<Barrel_detclass>(L, "Barrel_detclass");
	MakeAccessFunctions<Barrel_detclass>(L, "IonChamber_detclass");
	MakeAccessFunctions<CRDC_detclass>(L, "CRDC_detclass");
	MakeAccessFunctions<MTDC_detclass>(L, "MTDC_detclass");
//	MakeAccessFunctions<TriggerPack>(L, "TriggerPack");
//	MakeAccessFunctions<TOFPack>(L, "TOFPack");
//	MakeAccessFunctions<ScintPack>(L, "ScintPack");
//	MakeAccessFunctions<CRDCPack>(L, "CRDCPack");
//	MakeAccessFunctions<ICPack>(L, "ICPack");
//	MakeAccessFunctions<TPPACPack>(L, "TPPACPack");
//	MakeAccessFunctions<HodoPack>(L, "HodoPack");

	return 0;
}

#ifdef __CINT__

#pragma link C++ class SIDAR_detclass+;
#pragma link C++ class vector<SIDAR_detclass>+;
#pragma link C++ class Barrel_detclass+;
#pragma link C++ class IonChamber_detclass+;
#pragma link C++ class CRDC_detclass+;
#pragma link C++ class MTDC_detclass+;
//#pragma link C++ class TriggerPack+;
//#pragma link C++ class TOFPack+;
//#pragma link C++ class ScintPack+;
//#pragma link C++ class CRDCPack+;
//#pragma link C++ class ICPack+;
//#pragma link C++ class TPPACPack+;
//#pragma link C++ class HodoPack+;

#endif
