
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadges
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
        AND Tags IS NOT NULL
    GROUP BY 
        TagName
),
RankedPosts AS (
    SELECT 
        ps.*, 
        @rownum := @rownum + 1 AS Rank
    FROM 
        PostStats ps, (SELECT @rownum := 0) r
    ORDER BY 
        Score DESC, AnswerCount DESC
)

SELECT 
    rp.Rank,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.UserBadges,
    ts.TagName,
    ts.PostCount
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON FIND_IN_SET(ts.TagName, rp.Tags)
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
