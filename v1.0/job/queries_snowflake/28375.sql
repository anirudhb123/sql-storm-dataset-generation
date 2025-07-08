
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        a.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.kind_id
),
MovieDetails AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.kind_id,
        info.info,
        ki.keyword
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type info ON mi.info_type_id = info.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.kind_id,
    COUNT(DISTINCT md.info) AS info_count,
    COUNT(DISTINCT md.keyword) AS keyword_count,
    LISTAGG(DISTINCT md.info, '; ') WITHIN GROUP (ORDER BY md.info) AS all_info,
    LISTAGG(DISTINCT md.keyword, ', ') WITHIN GROUP (ORDER BY md.keyword) AS all_keywords
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.kind_id
ORDER BY 
    md.production_year DESC, md.title;
