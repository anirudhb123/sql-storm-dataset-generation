WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TopScoringPosts AS (
    SELECT 
        RP.*, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Votes v ON RP.PostId = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = RP.OwnerUserId
    WHERE 
        RP.RankByScore <= 5
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.OwnerDisplayName, RP.AnswerCount
)
SELECT 
    TSP.Title,
    TSP.CreationDate,
    TSP.Score,
    TSP.OwnerDisplayName,
    TSP.AnswerCount,
    TSP.UpVotesCount,
    TSP.DownVotesCount,
    CASE 
        WHEN TSP.HighestBadgeClass = 1 THEN 'Gold'
        WHEN TSP.HighestBadgeClass = 2 THEN 'Silver'
        WHEN TSP.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS HighestBadge
FROM 
    TopScoringPosts TSP
ORDER BY 
    TSP.Score DESC, TSP.CreationDate DESC;
