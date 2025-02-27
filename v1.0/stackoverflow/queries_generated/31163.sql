WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        CAST(ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS INT) AS Rank
    FROM Users
    WHERE CreationDate < '2022-01-01'
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        CAST(ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS INT) + uh.Rank
    FROM Users u
    JOIN UserHierarchy uh ON u.LastAccessDate < uh.LastAccessDate
    WHERE u.CreationDate >= '2022-01-01'
),
TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        Rank
    FROM UserHierarchy
    WHERE Rank <= 50
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId IS NOT NULL, False) AS HasAcceptedAnswer,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY ph.PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        pp.HasAcceptedAnswer,
        pp.CommentsCount,
        pp.Upvotes,
        ph.EditCount,
        ph.LastEditDate
    FROM PopularPosts pp
    JOIN Posts p ON pp.Id = p.Id
    LEFT JOIN PostHistories ph ON p.Id = ph.PostId
)
SELECT 
    pu.DisplayName AS TopUser,
    pd.Title AS PopularPost,
    pd.CreationDate AS PostCreatedDate,
    pd.Score AS PostScore,
    pd.CommentsCount,
    pd.Upvotes,
    pd.EditCount,
    pd.LastEditDate,
    CASE 
        WHEN pd.HasAcceptedAnswer THEN 'Yes'
        ELSE 'No'
    END AS AcceptedAnswer,
    CASE 
        WHEN pd.CreationDate < NOW() - INTERVAL '30 days' THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostCategory
FROM TopUsers pu
JOIN PostDetails pd ON pu.Id = pd.PostId
ORDER BY pu.Reputation DESC, pd.Upvotes DESC;
