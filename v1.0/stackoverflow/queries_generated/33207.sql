WITH RecursiveTagCTE AS (
    SELECT 
        Id, 
        TagName, 
        Count, 
        1 AS Level 
    FROM 
        Tags 
    WHERE 
        IsModeratorOnly = 1 
    
    UNION ALL 
    
    SELECT 
        t.Id, 
        t.TagName, 
        t.Count, 
        r.Level + 1 
    FROM 
        Tags t 
    INNER JOIN 
        RecursiveTagCTE r ON t.Count < r.Count 
),

UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews, 
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments, 
        RANK() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments GROUP BY PostId) c ON c.PostId = p.Id 
    GROUP BY 
        u.Id, u.DisplayName
),

VoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName, 
    u.TotalViews, 
    u.TotalComments,
    COALESCE(v.UpVotes, 0) AS UpVotes, 
    COALESCE(v.DownVotes, 0) AS DownVotes,
    RANK() OVER (ORDER BY u.TotalViews DESC) AS ViewsRank,
    rt.TagName,
    rt.Level AS TagLevel
FROM 
    UserActivity u 
LEFT JOIN 
    VoteStats v ON u.UserId = v.PostId 
LEFT JOIN 
    RecursiveTagCTE rt ON rt.Id IN (SELECT UNNEST(string_to_array(Posts.Tags, '><')))
WHERE 
    u.Rank = 1 
ORDER BY 
    u.TotalViews DESC 
LIMIT 10;


