WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(p.Tags, '>')) AS t(TagName) -- Assuming tags are formatted in a recognizable way
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE 
                WHEN v.VoteTypeId = 2 THEN 1 -- Upvotes
                WHEN v.VoteTypeId = 3 THEN -1 -- Downvotes
                ELSE 0 
            END) AS NetReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Author,
    ut.DisplayName AS TopUser,
    ut.NetReputation,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ut ON ut.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(rp.Tags, '>'))
WHERE 
    rp.PostRank = 1 -- Only take the latest question for each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
