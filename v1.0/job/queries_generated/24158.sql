WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) * 100 AS female_percentage,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM title t
    LEFT JOIN cast_info c ON c.movie_id = t.id
    LEFT JOIN aka_name a ON a.person_id = c.person_id
    LEFT JOIN name p ON p.id = a.person_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.female_percentage
    FROM RankedMovies rm
    WHERE rm.rank_within_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.female_percentage,
        AVG(m_info.info::float) AS average_review_score
    FROM TopMovies tm
    LEFT JOIN movie_info m_info ON m_info.movie_id = tm.movie_id AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'review score')
    WHERE COALESCE(m_info.info, '0')::float > 0
    GROUP BY tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.female_percentage
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.female_percentage,
    COALESCE(md.average_review_score, 0) AS adjusted_review_score,
    CASE 
        WHEN md.average_review_score IS NULL THEN 'Review score not available'
        WHEN md.average_review_score >= 8 THEN 'Highly rated'
        WHEN md.average_review_score >= 5 THEN 'Moderately rated'
        ELSE 'Poorly rated'
    END AS rating_category
FROM MovieDetails md
LEFT JOIN (
    SELECT 
        company_id, 
        COUNT(DISTINCT movie_id) AS movie_count 
    FROM movie_companies 
    GROUP BY company_id 
    HAVING COUNT(DISTINCT movie_id) > 5
) high_output_companies ON high_output_companies.company_id = 1
WHERE md.production_year > 2000
ORDER BY md.production_year DESC, md.cast_count DESC
FETCH FIRST 10 ROWS ONLY;
