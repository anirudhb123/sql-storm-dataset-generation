
WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role AS character_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(CD.company_names, 'No Companies') AS companies,
        COALESCE(CD.company_types, 'No Types') AS types,
        ARRAY_AGG(DISTINCT KR.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        CompanyDetails CD ON t.movie_id = CD.movie_id
    LEFT JOIN 
        movie_keyword MK ON t.movie_id = MK.movie_id
    LEFT JOIN 
        keyword KR ON MK.keyword_id = KR.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, CD.company_names, CD.company_types
),
RankedMovies AS (
    SELECT 
        F.movie_id,
        F.title,
        F.companies,
        F.types,
        F.keywords,
        ROW_NUMBER() OVER (ORDER BY F.title) AS rank
    FROM 
        FilteredMovies F
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.companies,
    RM.types,
    RM.keywords,
    RM.rank,
    MR.character_role,
    COUNT(MR.character_role) OVER (PARTITION BY RM.movie_id) AS role_count
FROM 
    RankedMovies RM
LEFT JOIN 
    MovieRoles MR ON RM.movie_id = MR.movie_id
WHERE 
    RM.rank <= 100
ORDER BY 
    RM.rank, MR.role_order;
