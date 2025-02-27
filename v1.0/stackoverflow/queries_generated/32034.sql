WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.Reputation,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) 
        ) AS PostTags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1  -- Gold badges
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND u.Reputation > 100
),
RecentEdits AS (
    SELECT 
        pe.PostId,
        MAX(pe.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory pe
    WHERE 
        pe.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        pe.PostId
),
TopScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        re.LastEditDate,
        re.EditCount,
        CASE 
            WHEN rv.Rank IS NOT NULL THEN 'Popular'
            ELSE 'Standard'
        END AS PostType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank 
         FROM Posts p 
         WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '90 days' 
           AND p.Score > 50) rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.LastEditDate,
    tp.EditCount,
    tp.PostType,
    rp.UserBadge,
    rp.CommentCount,
    rg.PostTags
FROM 
    TopScoringPosts tp
JOIN 
    RankedPosts rp ON tp.PostId = rp.PostId
WHERE 
    tp.Rank <= 5
ORDER BY 
    tp.Score DESC, tp.LastEditDate DESC;
