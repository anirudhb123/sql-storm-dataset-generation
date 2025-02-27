-- Performance Benchmarking Query for Stack Overflow Schema

WITH PostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Adjust date filter as needed
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostTypesSummary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(pd.PostId) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - pd.PostCreationDate)) / 3600) AS AvgPostAgeHours,
        SUM(pd.CommentCount) AS TotalComments,
        SUM(pd.UpVotes) AS TotalUpVotes,
        SUM(pd.DownVotes) AS TotalDownVotes,
        SUM(pd.BadgeCount) AS TotalBadges
    FROM 
        PostData pd
    JOIN 
        PostTypes pt ON pd.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    TotalPosts,
    AvgPostAgeHours,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalBadges
FROM 
    PostTypesSummary
ORDER BY 
    TotalPosts DESC;
