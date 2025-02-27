WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(COUNT(DISTINCT ph.PostId), 0) AS PostEditCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    WHERE 
        u.CreationDate < NOW() - INTERVAL '1 month'
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ua.DisplayName,
        ua.UpVoteCount,
        ua.DownVoteCount,
        ua.PostEditCount,
        ua.CommentCount,
        CASE 
            WHEN rp.Score >= 10 THEN 'High Scorer' 
            WHEN rp.Score BETWEEN 1 AND 9 THEN 'Moderate Scorer' 
            ELSE 'Low Scorer' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.OwnerUserId = ua.UserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    pd.*,
    COALESCE(TAGS, 'No Tags') AS Tags,
    PARTITIONED_RANK,
    CASE
        WHEN pd.ViewCount IS NULL THEN 'No Views'
        ELSE CAST(pd.ViewCount AS VARCHAR)
    END AS ViewCountDisplay
FROM 
    PostDetails pd
LEFT JOIN 
    (SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TAGS
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')))
    GROUP BY 
        p.Id) AS TagAgg ON pd.PostId = TagAgg.PostId
JOIN 
    (SELECT 
        p.Id, 
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS PARTITIONED_RANK 
    FROM 
        Posts p
    ) AS Ranking ON pd.PostId = Ranking.Id
WHERE 
    pd.PostEditCount > 0
ORDER BY 
    pd.CreationDate DESC, 
    pd.Score DESC
LIMIT 100;
