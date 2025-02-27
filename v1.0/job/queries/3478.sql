WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
AwardWinningMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(COUNT(mi.id), 0) AS award_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'award')
    WHERE 
        m.rank <= 10
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
    HAVING 
        COUNT(*) > 1
)
SELECT 
    awm.title,
    awm.production_year,
    awm.award_count,
    tc.company_name,
    tc.company_type,
    tc.movie_count
FROM 
    AwardWinningMovies awm
LEFT JOIN 
    TopCompanies tc ON awm.movie_id = tc.movie_id
WHERE 
    awm.award_count > 0
ORDER BY 
    awm.production_year DESC, 
    awm.award_count DESC;
