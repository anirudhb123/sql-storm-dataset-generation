
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMPADD(YEAR, -1, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    CONCAT('This post has ', fp.CommentCount, ' comments and ', fp.UpVotes, ' upvotes.') AS Summary,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    FilteredPosts fp
    LEFT JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6) numbers
        WHERE 
            CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '><', '')) >= numbers.n - 1
    ) AS t ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.Tags, fp.OwnerDisplayName, fp.CreationDate, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.UpVotes DESC, fp.CommentCount DESC;
