WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Top 10 Posts for each PostType
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    pt.Name AS PostType
FROM 
    FilteredPosts fp
JOIN 
    PostTypes pt ON fp.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
ORDER BY 
    pt.Name, fp.UpVotes DESC;
