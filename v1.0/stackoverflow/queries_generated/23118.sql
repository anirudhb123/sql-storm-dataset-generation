WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),

HighScoringPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.Score IS NULL THEN 0
            WHEN rp.Score < 10 THEN 'Low' 
            WHEN rp.Score BETWEEN 10 AND 50 THEN 'Medium'
            ELSE 'High'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score IS NOT NULL
        AND rp.ViewCount > 100
),

PostHistoryComments AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS TotalHistoryChanges,
        array_agg(DISTINCT ph.Comment) AS Comments,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    hp.PostId,
    hp.Title,
    hp.CreationDate,
    hp.ViewCount,
    hp.Score,
    hp.ScoreCategory,
    phc.TotalHistoryChanges,
    phc.Comments,
    phc.LastChangeDate,
    (SELECT
         COUNT(*) 
     FROM 
         Votes v 
     WHERE 
         v.PostId = hp.PostId AND 
         v.VoteTypeId = 2 /* UpMod */
    ) AS UpVoteCount,
    (SELECT 
         COUNT(*) 
     FROM 
         Votes v 
     WHERE 
         v.PostId = hp.PostId AND 
         v.VoteTypeId = 3 /* DownMod */
    ) AS DownVoteCount
FROM 
    HighScoringPosts hp
LEFT JOIN 
    PostHistoryComments phc ON hp.PostId = phc.PostId
WHERE 
    hp.CreationDate = (
        SELECT 
            MAX(CreationDate) 
        FROM 
            HighScoringPosts hps
        WHERE 
            hps.OwnerUserId IS NOT NULL
            AND hps.ViewCount IS NOT NULL
    )
ORDER BY 
    hp.Score DESC, 
    phc.LastChangeDate DESC
LIMIT 100;
