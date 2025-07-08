
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS aka_names,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS popularity_rank
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info cc ON cc.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = cc.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.aka_names,
        rm.cast_count,
        rm.popularity_rank,
        mci.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mci ON mci.movie_id = rm.title_id
    LEFT JOIN 
        company_name cn ON cn.id = mci.company_id
    LEFT JOIN 
        company_type ct ON ct.id = mci.company_type_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.aka_names,
    LISTAGG(DISTINCT CONCAT(md.company_name, ' (', md.company_type, ')'), ', ') WITHIN GROUP (ORDER BY md.company_name) AS production_companies
FROM 
    MovieDetails md
WHERE 
    md.popularity_rank <= 5
GROUP BY 
    md.title, md.production_year, md.cast_count, md.aka_names
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
