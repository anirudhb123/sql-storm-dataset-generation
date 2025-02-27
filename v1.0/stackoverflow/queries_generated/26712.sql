WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Last year
),
MostViewedPosts AS (
    SELECT 
        PostID, 
        Title,
        Body,
        Tags,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn = 1 -- Only keep the most recent post per tag
        AND ViewCount > 1000 -- More than 1000 views
),
TopBadgedUsers AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) >= 5 -- Users with 5 or more badges
),
PostDetails AS (
    SELECT 
        mvp.Title,
        mvp.Body,
        mvp.ViewCount,
        mvp.Score,
        tbu.DisplayName AS TopUserName,
        tbu.BadgeCount
    FROM 
        MostViewedPosts mvp
    JOIN 
        TopBadgedUsers tbu ON mvp.OwnerDisplayName = tbu.DisplayName
    ORDER BY 
        mvp.Score DESC, mvp.ViewCount DESC
)
SELECT 
    pd.Title,
    pd.Body,
    pd.ViewCount,
    pd.Score,
    pd.TopUserName,
    pd.BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
JOIN 
    Posts p ON pd.Title = p.Title
JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS t ON TRUE
GROUP BY 
    pd.Title, pd.Body, pd.ViewCount, pd.Score, pd.TopUserName, pd.BadgeCount
ORDER BY 
    pd.Score DESC;
