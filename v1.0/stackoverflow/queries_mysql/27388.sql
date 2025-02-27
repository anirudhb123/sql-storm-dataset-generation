
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        (SELECT @row_number := 0, @current_user := NULL) r
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3 
)
SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsAggregated
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON fp.OwnerUserId = b.UserId
LEFT JOIN 
    (SELECT TagName FROM (
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', n.n), '><', -1)) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
             UNION ALL SELECT 9 UNION ALL SELECT 10) n
        WHERE 
            n.n <= (LENGTH(fp.Tags) - LENGTH(REPLACE(fp.Tags, '><', '')) + 1)
    ) t) ON TRUE
GROUP BY 
    fp.OwnerDisplayName, fp.Title, fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount
ORDER BY 
    UpVoteCount DESC, CommentCount DESC;
