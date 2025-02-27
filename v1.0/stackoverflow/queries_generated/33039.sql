WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions
    
    UNION ALL
    
    SELECT 
        a.Id,
        a.Title,
        a.Score,
        a.OwnerUserId,
        a.CreationDate,
        a.ParentId,
        rp.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePosts rp ON a.ParentId = rp.Id
    WHERE 
        a.PostTypeId = 2 -- Selecting Answer Posts
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MIN(p.CreationDate) AS FirstPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.UserId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    rp.Level AS AnswerLevel,
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
    CASE 
        WHEN us.FirstPostDate IS NULL THEN 'No Posts'
        ELSE TO_CHAR(us.FirstPostDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS UserFirstPostDate
FROM 
    Posts p
LEFT JOIN 
    RecursivePosts rp ON p.Id = rp.Id
JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId AND rv.UserId = us.UserId
WHERE 
    p.PostTypeId = 1 -- Select Questions Only
ORDER BY 
    TotalScore DESC, 
    p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
