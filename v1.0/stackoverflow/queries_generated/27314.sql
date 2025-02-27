WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY COALESCE(v.TotalVotes, 0) DESC) AS RankInLocation
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
),

TopPosts AS (
    SELECT 
        rp.*,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Badges b ON rp.Author = b.UserId
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(rp.Tags, ','))
    WHERE 
        rp.RankInLocation <= 5  -- Top 5 posts per location
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.Author, rp.CreationDate, rp.TotalVotes
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.Votes,
    tp.CreationDate,
    tp.CommentCount,
    tp.BadgeCount,
    tp.TagNames
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC; -- Order by date of creation
