
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankWithinTag
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, U.DisplayName
),
RankedTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount
    FROM (
        SELECT 
            value AS Tag,
            ViewCount
        FROM 
            Posts CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags)-2), '><')
        WHERE 
            PostTypeId = 1 
    ) AS TagsView
    GROUP BY 
        Tag
),
TopPostsByTag AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.TotalComments,
        rp.TotalUpVotes,
        rp.TotalDownVotes,
        rt.TotalPosts,
        rt.AvgViewCount
    FROM 
        RankedPosts rp
    JOIN 
        RankedTags rt ON rt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags)-2), '><'))
    WHERE 
        rp.RankWithinTag <= 5 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.TotalComments,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.TotalPosts,
    tp.AvgViewCount,
    CONCAT('https://stackoverflow.com/posts/', tp.PostId) AS PostLink
FROM 
    TopPostsByTag tp
ORDER BY 
    tp.TotalUpVotes DESC, 
    tp.TotalComments DESC;
