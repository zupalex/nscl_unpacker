#include <iostream>
#include <vector>

#include "UserClassBase.h"

using namespace std;

#define MaxHits 416
#define MaxCaenHits 160

// ----------------- ASICHit Class ------------------------- //

class ASICHit: public LuaUserClass {
// This class is for ASICs hit
public:
	ASICHit()
	{
	}

	int nhits = 0;
	vector<int> mbID, cbID, channel, energy;
	double time = 0;

	void Reset()
	{
		nhits = 0;
		time = 0;

		mbID.clear();
		cbID.clear();
		channel.clear();
		energy.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &mbID, "mbID", "vector<int>");
		AddAccessor(L, &cbID, "cbID", "vector<int>");
		AddAccessor(L, &channel, "channel", "vector<int>");
		AddAccessor(L, &energy, "energy", "vector<int>");
		AddAccessor(L, &time, "time", "double");
	}
};

// ----------------- CAENHit Class ------------------------- //

class CAENHit: public LuaUserClass {
//This class is for CAEN digitizer
public:
	CAENHit()
	{
	}

	int nhits = 0;
	vector<int> id, channel, data;

	void Reset()
	{
		nhits = 0;

		id.clear();
		channel.clear();
		data.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &id, "id", "vector<int>");
		AddAccessor(L, &data, "data", "vector<int>");
		AddAccessor(L, &channel, "channel", "vector<int>");
	}
};

// ----------------- TriggerPack Class ------------------------- //

class TriggerPack: public LuaUserClass {
//This class is for S800 Trigger
public:
	TriggerPack()
	{
	}

	int nhits = 0;
	vector<int> registr, s800, external1, external2, secondary;

	void Reset()
	{
		nhits = 0;

		registr.clear();
		s800.clear();
		external1.clear();
		external2.clear();
		secondary.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &registr, "registr", "vector<int>");
		AddAccessor(L, &s800, "s800", "vector<int>");
		AddAccessor(L, &external1, "external1", "vector<int>");
		AddAccessor(L, &external2, "external2", "vector<int>");
		AddAccessor(L, &secondary, "secondary", "vector<int>");
	}
};

// ----------------- TOFPack Class ------------------------- //

class TOFPack: public LuaUserClass {
//This class is for S800 time of flight
public:
	TOFPack()
	{
	}

	int nhits = 0;
	vector<int> rf, obj, xfp, tar, tac_obj, tac_xfp;

	void Reset()
	{
		nhits = 0;

		rf.clear();
		obj.clear();
		xfp.clear();
		tar.clear();
		tac_obj.clear();
		tac_xfp.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &rf, "rf", "vector<int>");
		AddAccessor(L, &obj, "obj", "vector<int>");
		AddAccessor(L, &xfp, "xfp", "vector<int>");
		AddAccessor(L, &tar, "tar", "vector<int>");
		AddAccessor(L, &tac_obj, "tac_obj", "vector<int>");
		AddAccessor(L, &tac_xfp, "tac_xfp", "vector<int>");
	}
};

// ----------------- ScintPack Class ------------------------- //

class ScintPack: public LuaUserClass {
//This class is for S800 Scintillator
public:
	ScintPack()
	{
	}

	int nhits = 0;
	vector<int> de_up, de_down, time_up, time_down;

	void Reset()
	{
		nhits = 0;

		de_up.clear();
		de_down.clear();
		time_up.clear();
		time_down.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &de_up, "de_up", "vector<int>");
		AddAccessor(L, &de_down, "de_down", "vector<int>");
		AddAccessor(L, &time_up, "time_up", "vector<int>");
		AddAccessor(L, &time_down, "time_down", "vector<int>");
	}
};

// ----------------- CRDCPack Class ------------------------- //

class CRDCPack: public LuaUserClass {
//This class is for S800 Cathode readout drift chamber
public:
	CRDCPack()
	{
	}

	int nhits = 0, rawCount = 0;
	vector<int> id, anode, tac, width;
	vector<vector<int>> data, sample, ch;

	void Reset()
	{
		nhits = 0;
		rawCount = 0;

		id.clear();
		anode.clear();
		tac.clear();
		width.clear();

		data.clear();
		sample.clear();
		ch.clear();
	}

	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &rawCount, "rawCount", "vector<int>");
		AddAccessor(L, &id, "id", "vector<int>");
		AddAccessor(L, &anode, "anode", "vector<int>");
		AddAccessor(L, &tac, "tac", "vector<int>");
		AddAccessor(L, &width, "width", "vector<int>");

		AddAccessor(L, &data, "data", "vector<vector<int>>");
		AddAccessor(L, &sample, "sample", "vector<vector<int>>");
		AddAccessor(L, &ch, "ch", "vector<vector<int>>");
	}
};

// ----------------- ICPack Class ------------------------- //

class ICPack: public LuaUserClass {
//This class is for S800 Ion Chamber
public:
	ICPack()
	{
		for (int i = 0; i < 16; i++)
			data.push_back(vector<int>());
	}

	int nhits = 0;
	vector<vector<int>> data;

	void Reset()
	{
		nhits = 0;

		for (int i = 0; i < 16; i++)
			data[i].clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");

		AddAccessor(L, &data, "data", "vector<vector<int>>");
	}
};

// ----------------- TPPACPack Class ------------------------- //

class TPPACPack: public LuaUserClass {
//This class is for S800 Tracking Parallel Plate Avalanche Counter
public:
	TPPACPack()
	{
	}

	int nhits = 0;
	vector<int> id, data, sample, ch;

	void Reset()
	{
		nhits = 0;

		id.clear();
		data.clear();
		sample.clear();
		ch.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &id, "id", "vector<int>");
		AddAccessor(L, &data, "data", "vector<int>");
		AddAccessor(L, &sample, "sample", "vector<int>");
		AddAccessor(L, &ch, "ch", "vector<int>");
	}
};

// ----------------- HodoPack Class ------------------------- //

class HodoPack: public LuaUserClass {
//This class is for S800 hodoscope
public:
	HodoPack()
	{
	}

	int nhits = 0;
	vector<int> ch, data, regA, regB, tac;

	void Reset()
	{
		nhits = 0;

		ch.clear();
		data.clear();
		regA.clear();
		regB.clear();
		tac.clear();
	}


	void MakeAccessors(lua_State* L)
	{
		AddAccessor(L, &nhits, "nhits", "int");
		AddAccessor(L, &ch, "ch", "vector<int>");
		AddAccessor(L, &data, "data", "vector<int>");
		AddAccessor(L, &regA, "regA", "vector<int>");
		AddAccessor(L, &regB, "regB", "vector<int>");
		AddAccessor(L, &tac, "tac", "vector<int>");
	}
};

extern "C" int openlib_nscl_2011_detclasses(lua_State* L)
{
	MakeAccessFunctions<ASICHit>(L, "ASICHit");
	MakeAccessFunctions<CAENHit>(L, "CAENHit");
	MakeAccessFunctions<TriggerPack>(L, "TriggerPack");
	MakeAccessFunctions<TOFPack>(L, "TOFPack");
	MakeAccessFunctions<ScintPack>(L, "ScintPack");
	MakeAccessFunctions<CRDCPack>(L, "CRDCPack");
	MakeAccessFunctions<ICPack>(L, "ICPack");
	MakeAccessFunctions<TPPACPack>(L, "TPPACPack");
	MakeAccessFunctions<HodoPack>(L, "HodoPack");

	return 0;
}

#ifdef __CINT__

#pragma link C++ class ASICHit+;
#pragma link C++ class CAENHit+;
#pragma link C++ class TriggerPack+;
#pragma link C++ class TOFPack+;
#pragma link C++ class ScintPack+;
#pragma link C++ class CRDCPack+;
#pragma link C++ class ICPack+;
#pragma link C++ class TPPACPack+;
#pragma link C++ class HodoPack+;

#endif
