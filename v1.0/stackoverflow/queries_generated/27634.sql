WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Author,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY ARRAY_AGG(DISTINCT TRIM(BOTH '<>' FROM UNNEST(string_to_array(p.Tags, '>')))) ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        ViewCount,
        CreationDate,
        Author,
        Reputation,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Get top 5 posts per tag
)
SELECT 
    f.PostId,
    f.Title,
    f.ViewCount,
    f.Author,
    f.Reputation,
    f.CommentCount,
    LENGTH(f.Body) AS BodyLength,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = f.PostId AND v.VoteTypeId IN (2, 3)) AS TotalVotes, -- Upvotes and Downvotes
    EXTRACT(DOW FROM f.CreationDate) AS CreationDayOfWeek, -- Day of the week post was created
    TO_CHAR(f.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS CreationDateFormatted
FROM 
    FilteredPosts f
ORDER BY 
    f.ViewCount DESC, 
    f.Reputation DESC;
