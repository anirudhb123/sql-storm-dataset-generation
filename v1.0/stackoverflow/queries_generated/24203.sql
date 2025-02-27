WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        SUM(CommentCount) OVER (PARTITION BY EXTRACT(MONTH FROM CreationDate)) AS MonthlyComments,
        COUNT(*) FILTER (WHERE AcceptedAnswerId <> -1) AS AnswersAccepted
    FROM 
        RankedPosts
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.CreationDate,
    ad.Score,
    ad.ViewCount,
    ad.MonthlyComments,
    ad.AnswersAccepted,
    CASE 
        WHEN ad.Score IS NULL THEN 'No Score'
        WHEN ad.Score > 100 THEN 'Hot Topic'
        ELSE 'Normal'
    END AS TopicHeat,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = ad.PostId AND v.VoteTypeId = 3 -- Down votes
        ) THEN 'Controversial'
        ELSE 'Stable'
    END AS PostNature
FROM 
    AggregatedData ad
LEFT JOIN 
    Posts p ON ad.PostId = p.Id
WHERE 
    ad.Rank <= 10
ORDER BY 
    ad.MonthlyComments DESC, ad.Score DESC
LIMIT 100
OFFSET 50;
