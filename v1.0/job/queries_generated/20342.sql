WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_rank
    FROM 
        aka_title t
        LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.keywords) AS keyword_count
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
        LEFT JOIN movie_keyword mk ON mc.movie_id = mk.movie_id
        LEFT JOIN keyword m ON mk.keyword_id = m.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
CastStats AS (
    SELECT 
        c.movie_id,
        COALESCE(SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END), 0) AS roles_filled,
        COUNT(DISTINCT c.person_id) AS unique_cast,
        AVG(r.role_id) AS average_role_id
    FROM 
        cast_info c
        LEFT JOIN role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieOverview AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cd.company_name, 'Independent') AS company_name,
        cs.roles_filled,
        cs.unique_cast,
        cs.average_role_id,
        COALESCE(cd.keyword_count, 0) AS keyword_count,
        (SELECT ARRAY_AGG(k.keyword ORDER BY k.keyword) 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = rm.movie_id) AS keywords
    FROM 
        RankedMovies rm
        LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
        LEFT JOIN CastStats cs ON rm.movie_id = cs.movie_id
    WHERE 
        rm.role_rank = 1 AND 
        (rm.production_year IS NOT NULL OR rm.production_year != 9999)
)
SELECT 
    mo.title,
    mo.production_year,
    mo.company_name,
    mo.roles_filled,
    mo.unique_cast,
    mo.average_role_id,
    mo.keyword_count,
    CASE 
        WHEN mo.roles_filled < mo.unique_cast THEN 'Understaffed'
        WHEN mo.roles_filled = mo.unique_cast THEN 'Well-staffed'
        ELSE 'Overstaffed'
    END AS staffing_status,
    STRING_AGG(DISTINCT k.keyword, ', ') AS combined_keywords
FROM 
    MovieOverview mo
    LEFT JOIN unnest(mo.keywords) AS k ON TRUE
GROUP BY 
    mo.title, mo.production_year, mo.company_name, mo.roles_filled, mo.unique_cast, mo.average_role_id, mo.keyword_count
ORDER BY 
    mo.production_year DESC, 
    staffing_status, 
    mo.unique_cast DESC
LIMIT 50;
