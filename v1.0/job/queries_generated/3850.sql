WITH MovieRoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY rc.role_count DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        MovieRoleCounts rc ON mt.id = rc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
TopRoles AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rank
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
MovieInfoWithKeywords AS (
    SELECT 
        ti.title AS movie_title,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        title ti
    LEFT JOIN 
        movie_keyword mk ON ti.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        ti.id
)
SELECT 
    tr.title,
    tr.production_year,
    tr.rank,
    mk.keywords,
    COUNT(ci.id) AS total_cast,
    MAX(pi.info) AS director_info
FROM 
    TopRoles tr
LEFT JOIN 
    complete_cast cc ON tr.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id AND pi.info_type_id = (SELECT MIN(it.id) FROM info_type it WHERE it.info = 'Director')
LEFT JOIN 
    MovieInfoWithKeywords mk ON tr.title = mk.movie_title
GROUP BY 
    tr.title, tr.production_year, tr.rank, mk.keywords
ORDER BY 
    tr.production_year DESC, tr.rank;
