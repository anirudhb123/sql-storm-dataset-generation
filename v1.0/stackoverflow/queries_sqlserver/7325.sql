
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
PopularTags AS (
    SELECT 
        VALUE AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        VALUE
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    pt.TagName,
    tu.DisplayName AS TopUserName,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' + pt.TagName + '%'
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
