WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, u.DisplayName
),
TopOwners AS (
    SELECT 
        Owner,
        COUNT(PostId) AS TotalPosts,
        AVG(CommentCount) AS AvgComments
    FROM 
        RankedPosts
    WHERE 
        Rnk <= 5
    GROUP BY 
        Owner
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    o.Owner,
    o.TotalPosts,
    o.AvgComments,
    p.Title,
    p.HistoryDate,
    p.UserDisplayName,
    p.Comment,
    COALESCE(r.UpVotes, 0) AS TotalUpVotes,
    COALESCE(r.DownVotes, 0) AS TotalDownVotes
FROM 
    TopOwners o
LEFT JOIN 
    PostHistoryDetails p ON o.Owner = p.UserDisplayName
LEFT JOIN 
    RankedPosts r ON p.PostId = r.PostId
ORDER BY 
    o.TotalPosts DESC, o.AvgComments DESC, p.HistoryDate DESC
OPTION (MAXRECURSION 0);
