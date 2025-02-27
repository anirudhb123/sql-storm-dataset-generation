WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        aka_title.title AS aka_title,
        RANK() OVER (PARTITION BY title.production_year ORDER BY title.imdb_index) AS year_rank
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    WHERE 
        title.production_year IS NOT NULL
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.aka_title,
        rm.production_year,
        count(distinct mci.company_id) AS company_count,
        count(distinct mi.info_type_id) AS info_count,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.aka_title, rm.production_year
),

TopMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.company_count DESC) AS rank_by_company
    FROM 
        MovieDetails md
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.aka_title,
    tm.production_year,
    tm.company_count,
    tm.info_count,
    tm.keywords,
    tm.rank_by_company
FROM 
    TopMovies tm
WHERE 
    tm.rank_by_company <= 10 
ORDER BY 
    tm.production_year DESC, 
    tm.company_count DESC;
