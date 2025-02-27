WITH RECURSIVE UserVoteCounts AS (
    SELECT UserId, COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.PostId = p.Id 
           AND ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider recent posts
),
TagUsage AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON p.Tags ILIKE '%' || tag.TagName || '%'  -- Using ILIKE for case-insensitive search
    GROUP BY 
        tag.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        TagCount > 5  -- Only consider tags with more than 5 usages
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(uv.TotalVotes, 0) AS UserVoteCount
    FROM 
        Users u
    LEFT JOIN 
        UserVoteCounts uv ON u.Id = uv.UserId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.CloseCount,
    tt.TagName,
    ur.UserId,
    ur.Reputation,
    ur.UserVoteCount
FROM 
    PostDetails pd
JOIN 
    TopTags tt ON pd.TagCount > 0
LEFT JOIN 
    UserReputation ur ON pd.OwnerUserId = ur.UserId
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC,
    tt.TagCount DESC
LIMIT 100;  -- Limit to top 100 results based on score

