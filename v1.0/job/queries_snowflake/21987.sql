
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    INNER JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
PersonRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info AS ci
    GROUP BY 
        ci.person_id
),
PersonDetails AS (
    SELECT
        a.id AS person_id,
        a.name,
        (SELECT COUNT(*) FROM aka_name WHERE person_id = a.id) AS aka_count,
        CASE 
            WHEN a.gender IS NULL THEN 'Unknown'
            ELSE a.gender
        END AS gender
    FROM 
        name AS a
)
SELECT 
    rm.title,
    rm.production_year,
    mk.keywords,
    pd.name AS actor_name,
    pd.gender,
    COALESCE(prc.role_count, 0) AS number_of_roles,
    CASE 
        WHEN rm.rank_count <= 3 THEN 'Top Movie'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieKeywords AS mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info AS ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    PersonDetails AS pd ON ci.person_id = pd.person_id
LEFT JOIN 
    PersonRoleCounts AS prc ON ci.person_id = prc.person_id
WHERE 
    rm.production_year >= 2000
    AND (pd.gender = 'F' OR pd.gender IS NULL)
    AND mk.keywords IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.rank_count, pd.name;
