WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.CreationDate IS NOT NULL AND vt.Name = 'UpMod') AS UpVotes,
        SUM(v.CreationDate IS NOT NULL AND vt.Name = 'DownMod') AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
)
SELECT 
    OwnerDisplayName,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    SUM(CommentCount) AS TotalComments,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes
FROM 
    TopPosts
GROUP BY 
    OwnerDisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC;
