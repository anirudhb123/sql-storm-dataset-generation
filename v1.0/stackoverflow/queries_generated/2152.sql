WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        u.DisplayName,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON rp.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Title and Body edits
    LEFT JOIN 
        Comments c ON rp.Id = c.PostId
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.Id, u.DisplayName, ph.Comment, ph.CreationDate
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(b.Class) > 0
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.DisplayName AS Owner,
    pd.LastEditComment,
    pd.LastEditDate,
    pd.CommentCount,
    pt.TagName,
    tu.BadgeCount
FROM 
    PostDetails pd
LEFT JOIN 
    PopularTags pt ON pd.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags ILIKE '%' || pt.TagName || '%')
JOIN 
    TopUsers tu ON pd.DisplayName = tu.DisplayName
WHERE 
    pd.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) -- Only above average score
ORDER BY 
    pd.Score DESC, 
    pt.TagCount DESC
LIMIT 10;
