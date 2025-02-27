WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY SUM(v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Tags
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Top 5 posts per tag
)

SELECT 
    f.Tags,
    COUNT(f.PostId) AS TotalPosts,
    SUM(f.UpVotes) AS TotalUpVotes,
    SUM(f.DownVotes) AS TotalDownVotes,
    AVG(f.CommentCount) AS AverageComments
FROM 
    FilteredPosts f
GROUP BY 
    f.Tags
ORDER BY 
    TotalPosts DESC, AverageComments DESC;
