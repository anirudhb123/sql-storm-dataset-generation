
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 100
),
UserInteractions AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Reputation,
    pt.TagName,
    ui.VoteCount,
    ui.UpVotes,
    ui.DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE '%' + pt.TagName + '%'
    )
LEFT JOIN 
    UserInteractions ui ON rp.PostId = (
        SELECT TOP 1 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ui.UserId 
            AND p.PostTypeId = 1
        ORDER BY 
            p.CreationDate DESC
    )
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
