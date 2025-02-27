
WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName as OwnerDisplayName,
        COUNT(c.Id) as CommentCount,
        COUNT(DISTINCT v.UserId) as VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC, COUNT(DISTINCT v.Id) DESC) as PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        tag, 
        COUNT(*) as TagCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
        FROM 
            Posts p 
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        WHERE 
            p.PostTypeId = 1 AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    ) AS tag_list
    GROUP BY 
        tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CommentCount,
        rp.VoteCount,
        pt.Name as PostTypeName,
        d.Name as CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = rp.PostId)
    LEFT JOIN 
        PostHistory ph ON ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes d ON d.Id = CAST(ph.Comment AS UNSIGNED)
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.Body,
    tpd.CommentCount,
    tpd.VoteCount,
    pt.TagCount,
    pt.tag
FROM 
    TopPostDetails tpd
JOIN 
    PopularTags pt ON INSTR(tpd.Body, pt.tag) > 0 
ORDER BY 
    tpd.VoteCount DESC, 
    tpd.CommentCount DESC;
