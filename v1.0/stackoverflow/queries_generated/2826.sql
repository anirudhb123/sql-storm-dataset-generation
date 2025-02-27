WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpVote
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Rank,
        rp.HasUpVote,
        ph.Type 
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.CreationDate >= NOW() - INTERVAL '1 month'
    WHERE 
        rp.Rank <= 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
    CASE 
        WHEN rp.HasUpVote = 1 THEN 'Yes'
        ELSE 'No'
    END AS UpVoted,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeName
FROM 
    RecentPosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount, rp.CreationDate, rp.Rank, rp.HasUpVote
ORDER BY 
    rp.ViewCount DESC;

WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ROW_NUMBER() OVER (ORDER BY ts.TotalViews DESC) AS TagRank
    FROM 
        TagStats ts
)
SELECT *
FROM TopTags
WHERE TagRank <= 5;
