WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND rp.Score > 100
),
PostDetails AS (
    SELECT 
        hp.PostId,
        hp.Title,
        hp.CreationDate,
        hp.ViewCount,
        hp.Score,
        COALESCE(b.Name, 'No Badge') AS Badge,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        CASE 
            WHEN hp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN hp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel
    FROM 
        HighScorePosts hp
    LEFT JOIN 
        Badges b ON hp.PostId = b.UserId -- Assumes UserId correlates to posts in this case
    LEFT JOIN 
        (SELECT DISTINCT unnest(string_to_array(p.Tags, ',')) AS TagName, p.Id
         FROM Posts p) t ON hp.PostId = t.Id
    GROUP BY 
        hp.PostId, hp.Title, hp.CreationDate, hp.ViewCount, hp.Score, b.Name
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.Badge,
        pd.Tags,
        pd.DiscussionLevel,
        PH.CreationDate AS HistoryDate,
        PH.Comment,
        PH.UserDisplayName
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistory PH ON pd.PostId = PH.PostId AND PH.CreationDate = (
            SELECT MAX(p2.CreationDate)
            FROM PostHistory p2
            WHERE p2.PostId = pd.PostId
              AND p2.PostHistoryTypeId IN (10, 11, 12)
        )
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.Badge,
    fr.Tags,
    fr.DiscussionLevel,
    COALESCE(fr.HistoryDate, 'No History') AS LastHistoryDate,
    COALESCE(fr.Comment, 'No Comment') AS LastComment,
    COALESCE(fr.UserDisplayName, 'Anonymous') AS CommentUser
FROM 
    FinalResults fr
WHERE 
    fr.ViewCount > 50
ORDER BY 
    fr.Score DESC, fr.ViewCount ASC;

-- Optional: Use a subset with UNION to include posts from a specific User
UNION ALL 
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    'User Post' AS Badge,
    'User Tags' AS Tags,
    'User Discussion Level' AS DiscussionLevel,
    NULL AS LastHistoryDate,
    NULL AS LastComment,
    NULL AS CommentUser
FROM 
    Posts p
WHERE 
    p.OwnerUserId = 123456 AND
    p.CreationDate > NOW() - INTERVAL '6 months';
