WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        CONCAT_WS(', ', COALESCE(u.DisplayName, 'Community')) AS OwnerDisplayName,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.Score, 0) AS Score,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.ViewCount, p.Score
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        LATERAL string_to_array(rp.Tags, '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.ViewCount, rp.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(u.DownVotes, 0)) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.TagList,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    us.TotalPosts,
    us.TotalBadges
FROM 
    TaggedPosts tp
JOIN 
    UserStats us ON tp.OwnerDisplayName = us.DisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
