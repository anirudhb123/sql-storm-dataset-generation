WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopRankedTitles AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),
CastDetails AS (
    SELECT 
        ca.movie_id, 
        a.name AS actor_name, 
        c.kind AS cast_type
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ca.person_role_id = c.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tt.title, 
    tt.production_year, 
    cd.actor_name, 
    cd.cast_type, 
    mc.company_name, 
    mc.company_type
FROM 
    TopRankedTitles tt
JOIN 
    CastDetails cd ON tt.title_id = cd.movie_id
JOIN 
    MovieCompanies mc ON tt.title_id = mc.movie_id
ORDER BY 
    tt.production_year DESC, 
    tt.title;
