WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        PostCount > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    AND 
        ph.CreationDate >= NOW() - INTERVAL '60 days'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CombinedData AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        COALESCE(p.Title, 'No Title') AS PostTitle,
        p.CreationDate AS PostCreationDate,
        pc.CommentCount,
        COALESCE(rp.rn, 0) AS RecentPostRank,
        tu.ReputationRank,
        CASE 
            WHEN cu.PostId IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        TopUsers tu
    JOIN 
        UserReputation ru ON tu.UserId = ru.UserId
    LEFT JOIN 
        RecentPosts rp ON ru.UserId = rp.OwnerUserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = ru.UserId
    LEFT JOIN 
        PostComments pc ON pc.PostId = p.Id
    LEFT JOIN 
        ClosedPosts cu ON cu.PostId = p.Id
)
SELECT 
    UserId,
    DisplayName,
    COUNT(PostTitle) FILTER (WHERE PostStatus = 'Open') AS OpenPosts,
    COUNT(PostTitle) FILTER (WHERE PostStatus = 'Closed') AS ClosedPosts,
    AVG(CommentCount) AS AverageComments,
    SUM(CASE WHEN RecentPostRank <= 3 THEN 1 ELSE 0 END) AS RecentTopPosts
FROM 
    CombinedData
GROUP BY 
    UserId, DisplayName
ORDER BY 
    ReputationRank;
