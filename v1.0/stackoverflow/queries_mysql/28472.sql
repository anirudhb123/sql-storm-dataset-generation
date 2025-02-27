
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorName,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT GROUP_CONCAT(b.Name SEPARATOR ', ') FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadges
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        @row_num := @row_num + 1 AS TagRank
    FROM 
        TagStatistics, (SELECT @row_num := 0) r
    WHERE 
        TagCount > 5 
    ORDER BY TagCount DESC
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.AuthorName,
        pd.CommentCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        pd.UserBadges,
        tt.Tag,
        @post_rank := IF(@current_tag = tt.Tag, @post_rank + 1, 1) AS PostRank,
        @current_tag := tt.Tag
    FROM 
        PostDetails pd
    CROSS JOIN 
        TopTags tt,
        (SELECT @post_rank := 0, @current_tag := NULL) p
    WHERE 
        EXISTS (
            SELECT 1 
            FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Tags, '><', numbers.n), '><', -1) AS Tag
                  FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
                  WHERE CHAR_LENGTH(pd.Tags) - CHAR_LENGTH(REPLACE(pd.Tags, '><', '')) >= numbers.n - 1) as tbl
            WHERE tbl.Tag = tt.Tag
        )
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.AuthorName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.UserBadges,
    rp.Tag,
    rp.PostRank
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.Tag, rp.UpVoteCount DESC;
