WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.kind_id ORDER BY title.production_year DESC) AS rank
    FROM 
        aka_title AS title
    JOIN 
        movie_keyword AS mk ON mk.movie_id = title.id
    JOIN 
        keyword AS k ON k.id = mk.keyword_id
    WHERE 
        k.keyword LIKE '%action%'
), MovieCast AS (
    SELECT 
        cm.movie_id,
        GROUP_CONCAT(p.name ORDER BY ci.nr_order) AS cast_names,
        COUNT(ci.person_id) AS cast_count
    FROM 
        complete_cast AS cm
    JOIN 
        cast_info AS ci ON ci.movie_id = cm.movie_id
    JOIN 
        aka_name AS p ON p.person_id = ci.person_id
    GROUP BY 
        cm.movie_id
), MovieGenres AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT gt.kind ORDER BY gt.kind) AS genres
    FROM 
        movie_companies AS mc
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    JOIN 
        kind_type AS gt ON gt.id = mc.company_id
    WHERE 
        ct.kind IN ('Production', 'Distribution')
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    mc.cast_names,
    mc.cast_count,
    mg.genres
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieCast AS mc ON mc.movie_id = rm.movie_id
LEFT JOIN 
    MovieGenres AS mg ON mg.movie_id = rm.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC;
