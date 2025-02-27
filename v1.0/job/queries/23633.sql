WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mci.person_id) AS num_people_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info mci ON mc.movie_id = mci.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mci.num_people_involved, 0) AS num_people_involved,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        (COALESCE(mci.num_people_involved, 0) + COALESCE(mkc.keyword_count, 0)) AS total_involvement
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        MovieKeywordCount mkc ON rm.movie_id = mkc.movie_id
    WHERE 
        rm.rank_year <= 5
),

FinalReport AS (
    SELECT 
        title,
        production_year,
        num_people_involved,
        keyword_count,
        total_involvement,
        NTILE(4) OVER (ORDER BY total_involvement DESC) AS involvement_quartile
    FROM 
        TopMovies
    WHERE 
        num_people_involved > 0 OR keyword_count > 0
)

SELECT 
    fr.title,
    fr.production_year,
    fr.num_people_involved,
    fr.keyword_count,
    fr.total_involvement,
    fr.involvement_quartile,
    CASE 
        WHEN fr.involvement_quartile = 1 THEN 'Very High Involvement'
        WHEN fr.involvement_quartile = 2 THEN 'High Involvement'
        WHEN fr.involvement_quartile = 3 THEN 'Low Involvement'
        ELSE 'Very Low Involvement'
    END AS involvement_description
FROM 
    FinalReport fr
ORDER BY 
    fr.total_involvement DESC, fr.production_year ASC;


