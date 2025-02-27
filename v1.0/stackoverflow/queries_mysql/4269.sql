
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH)
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.PostTypeId, p.CreationDate
),
PostStats AS (
    SELECT
        PostId,
        Title,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        (UpvoteCount - DownvoteCount) AS NetVotes,
        CASE 
            WHEN CommentCount > 10 THEN 'Highly Discussed'
            WHEN UpvoteCount > DownvoteCount THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.NetVotes,
    ps.Popularity,
    COALESCE((
        SELECT GROUP_CONCAT(t.TagName SEPARATOR ', ')
        FROM Tags t
        JOIN (
            SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
            FROM 
                (SELECT @row := @row + 1 AS n FROM 
                    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS numbers,
                    (SELECT @row := 0) AS r) AS numbers
            WHERE n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
        ) AS split_tags ON t.TagName = split_tags.tag
        WHERE p.Id = ps.PostId
    ), 'No Tags') AS Tags
FROM 
    PostStats ps
LEFT JOIN 
    Posts p ON ps.PostId = p.Id
ORDER BY 
    ps.NetVotes DESC, ps.CommentCount DESC
LIMIT 20;
