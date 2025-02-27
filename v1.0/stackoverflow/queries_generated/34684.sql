WITH RECURSIVE UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        1 AS Level -- Start from level 1
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Consider users with reputation greater than 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputations ur ON u.Reputation > ur.Reputation -- Join to get users with higher reputation
    WHERE 
        ur.Level < 5 -- Limit the recursion to 5 levels
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostsWithTags AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '<>')) AS tagName ON TRUE
    JOIN 
        Tags t ON t.TagName = tagName
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        STRING_AGG(crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only closed posts
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    pwt.Id AS PostId,
    pwt.Title,
    pwt.CreationDate,
    pvt.Upvotes,
    pvt.Downvotes,
    cp.CloseDate,
    cp.CloseReasons
FROM 
    Users u
JOIN 
    UserReputations ur ON u.Id = ur.UserId
JOIN 
    PostsWithTags pwt ON ur.UserId = pwt.OwnerUserId
LEFT JOIN 
    PostVotes pvt ON pwt.Id = pvt.PostId
LEFT JOIN 
    ClosedPosts cp ON pwt.Id = cp.PostId
WHERE 
    ur.Reputation > 1500
ORDER BY 
    ur.Reputation DESC,
    pwt.CreationDate DESC
LIMIT 50; -- Limit the result for performance benchmarking
