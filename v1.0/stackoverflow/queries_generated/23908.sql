WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS t(TagName) ON true
    GROUP BY 
        p.Id
),
MaxScorePost AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        CommentCount,
        RankScore,
        TagsArray
    FROM 
        RankedPosts
    WHERE 
        Score = (SELECT MAX(Score) FROM RankedPosts)
),
PostActivities AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastActivityDate,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryNames
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        ph.PostId
)
SELECT 
    mp.PostId,
    mp.Title,
    mp.CreationDate,
    mp.Score,
    mp.CommentCount,
    mp.RankScore,
    mp.TagsArray,
    pa.LastActivityDate,
    pa.PostHistoryNames,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = mp.PostId AND 
        v.VoteTypeId IN (2, 4) /* UpMod or Offensive votes */
    ) AS PositiveVotes,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = mp.PostId AND 
        v.VoteTypeId = 3 /* DownMod votes */
    ) AS NegativeVotes,
    (SELECT 
        STRING_AGG(b.Name, ', ') 
     FROM 
        Badges b 
     WHERE 
        b.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = mp.PostId)
    ) AS BadgeList
FROM 
    MaxScorePost mp
LEFT JOIN 
    PostActivities pa ON mp.PostId = pa.PostId
WHERE 
    mp.RankScore <= 5 -- limit to top 5 based on score
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p2 
        WHERE p2.Id = mp.PostId AND p2.ClosedDate IS NOT NULL
    )
ORDER BY 
    mp.Score DESC, pa.LastActivityDate ASC;
