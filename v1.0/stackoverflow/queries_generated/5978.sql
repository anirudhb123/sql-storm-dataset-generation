WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC, SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Rank <= 10
ORDER BY 
    rp.Rank, pt.PostCount DESC
LIMIT 50;
