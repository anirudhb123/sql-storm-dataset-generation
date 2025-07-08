
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorName,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadges
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01')
),
TagStatistics AS (
    SELECT 
        TRIM(tag) AS Tag,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1 
    )
    GROUP BY 
        TRIM(tag)
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 5 
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.AuthorName,
        pd.CommentCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        pd.UserBadges,
        tt.Tag,
        ROW_NUMBER() OVER (PARTITION BY tt.Tag ORDER BY pd.UpVoteCount DESC) AS PostRank
    FROM 
        PostDetails pd
    JOIN 
        TagStatistics ts ON ts.Tag IN (
            SELECT TRIM(tag)
            FROM FLATTEN(input => SPLIT(SUBSTRING(pd.Tags, 2, LEN(pd.Tags) - 2), '><'))
        )
    JOIN 
        TopTags tt ON tt.Tag = ts.Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.AuthorName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.UserBadges,
    rp.Tag,
    rp.PostRank
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.Tag, rp.UpVoteCount DESC;
