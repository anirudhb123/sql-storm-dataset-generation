WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) as UpVotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) as DownVotes,
        COALESCE(CAST(SUBSTRING(p.Body FROM '<p>[^<]*</p>') AS TEXT), 'No Body') AS ShortDescription
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(rp.Id) > 5
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><'))::int[]
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.ShortDescription,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    t.TagName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PopularTags t ON rp.Tags ILIKE '%' || t.TagName || '%'
WHERE 
    rp.rn = 1
ORDER BY 
    u.TotalViews DESC, rp.ViewCount DESC 
LIMIT 10 OFFSET 0;
