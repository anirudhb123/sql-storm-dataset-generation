WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalBounty,
        ua.PostCount,
        ua.CommentCount,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity ua
    WHERE 
        ua.Reputation > 0
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ',') AS tagNames ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagNames
    GROUP BY 
        p.Id, p.Title
),
PostDetails AS (
    SELECT 
        pu.UserId,
        pu.DisplayName,
        pu.ReputationRank,
        pt.PostId,
        pt.Title,
        pt.Tags,
        CASE 
            WHEN ph.PostId IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS PostStatus
    FROM 
        TopUsers pu
    JOIN 
        PostsWithTags pt ON pu.UserId = pt.PostId
    LEFT JOIN 
        PostHistory ph ON pt.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 -- Closed posts
)

SELECT 
    pd.UserId,
    pd.DisplayName,
    pd.ReputationRank,
    pd.Title,
    pd.Tags,
    pd.PostStatus,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(uv.Reputation) AS AverageReputation,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
LEFT JOIN 
    Users uv ON uv.Id = pd.UserId
GROUP BY 
    pd.UserId, pd.DisplayName, pd.ReputationRank, pd.Title, pd.Tags, pd.PostStatus
HAVING 
    COUNT(DISTINCT c.Id) > 5 OR SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) > 10
ORDER BY 
    pd.ReputationRank;
