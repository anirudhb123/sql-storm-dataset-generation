
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT TOP 10
        UserId, 
        DisplayName, 
        PostCount
    FROM 
        UserPostCounts
    ORDER BY 
        PostCount DESC
),
RecentPosts AS (
    SELECT TOP 10
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS Author
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    ORDER BY 
        p.CreationDate DESC
)

SELECT 
    u.DisplayName AS TopUser, 
    u.PostCount, 
    r.PostId, 
    r.Title AS RecentPostTitle, 
    r.CreationDate AS RecentPostDate, 
    r.Author
FROM 
    TopUsers u
FULL OUTER JOIN 
    RecentPosts r ON u.DisplayName = r.Author
ORDER BY 
    u.PostCount DESC, 
    r.CreationDate DESC;
